using System.Reflection;
using System.Runtime.InteropServices;

namespace DotnetScanner;

public static class AssemblyScanner
{
    public static AssemblyInventory Scan(string assemblyPath)
    {
        var fullPath = Path.GetFullPath(assemblyPath);
        var resolver = BuildResolver(fullPath);
        using var context = new MetadataLoadContext(resolver);

        var assembly = context.LoadFromAssemblyPath(fullPath);
        var types = LoadTypes(assembly)
            .Where(t => !IsCompilerGenerated(t))
            .ToList();

        var grouped = types
            .GroupBy(t => t.Namespace ?? "(global)")
            .OrderBy(g => g.Key)
            .Select(g => new NamespaceInventory
            {
                Namespace = g.Key,
                Types = g.OrderBy(t => t.Name).Select(InventoryType).ToList()
            })
            .ToList();

        return new AssemblyInventory
        {
            Assembly = assembly.GetName().Name ?? Path.GetFileNameWithoutExtension(fullPath),
            Path = assemblyPath,
            Namespaces = grouped
        };
    }

    static TypeInventory InventoryType(Type type)
    {
        var inv = new TypeInventory
        {
            Name = FormatTypeName(type),
            Kind = TypeKind(type),
            IsPublic = type.IsPublic || type.IsNestedPublic,
            IsAbstract = type.IsAbstract && !type.IsInterface,
            IsSealed = type.IsSealed && !type.IsAbstract,
            IsStatic = type.IsAbstract && type.IsSealed,
            BaseType = FormatBaseType(type),
            Interfaces = ExtractInterfaces(type),
            Attributes = ExtractAttributes(type.GetCustomAttributesData()),
            Constructors = ExtractConstructors(type),
            Methods = ExtractMethods(type),
            Properties = ExtractProperties(type),
            Fields = ExtractFields(type),
        };

        if (type.IsGenericTypeDefinition)
        {
            inv.GenericParameters = type.GetGenericArguments().Select(a => a.Name).ToList();
        }

        var nested = type.GetNestedTypes(BindingFlags.Public)
            .Where(t => !IsCompilerGenerated(t))
            .Select(t => FormatTypeName(t))
            .ToList();
        if (nested.Count > 0) inv.NestedTypes = nested;

        var tags = ExtractTags(type.GetCustomAttributesData());
        if (tags.Count > 0) inv.Tags = tags;

        return inv;
    }

    static string TypeKind(Type type)
    {
        if (type.IsEnum) return "enum";
        if (type.IsInterface) return "interface";
        if (type.IsValueType) return "struct";
        if (type.BaseType?.FullName == "System.MulticastDelegate") return "delegate";
        return "class";
    }

    static string? FormatBaseType(Type type)
    {
        if (type.IsInterface || type.IsEnum || type.IsValueType) return null;
        if (type.BaseType == null) return null;

        var baseName = FormatTypeRef(type.BaseType);
        if (baseName is "object" or "ValueType" or "Enum" or "MulticastDelegate") return null;
        return baseName;
    }

    static List<string> ExtractInterfaces(Type type)
    {
        var declared = type.GetInterfaces().AsEnumerable();

        if (type.BaseType != null)
        {
            var inherited = new HashSet<Type>(type.BaseType.GetInterfaces());
            declared = declared.Where(i => !inherited.Contains(i));
        }

        return declared
            .Select(FormatTypeRef)
            .OrderBy(n => n)
            .ToList();
    }

    static List<ConstructorDecl> ExtractConstructors(Type type)
    {
        if (type.IsInterface || type.IsEnum) return [];

        return type.GetConstructors(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.DeclaredOnly)
            .Where(c => !c.IsStatic)
            .Select(c => new ConstructorDecl
            {
                IsPublic = c.IsPublic,
                Parameters = c.GetParameters().Select(p => new ParamDecl
                {
                    Name = p.Name ?? "",
                    Type = FormatTypeRef(p.ParameterType)
                }).ToList()
            })
            .ToList();
    }

    static List<MethodDecl> ExtractMethods(Type type)
    {
        var flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly;

        return type.GetMethods(flags)
            .Where(m => !m.IsSpecialName && !IsCompilerGenerated(m))
            .Select(m => new MethodDecl
            {
                Name = m.Name,
                IsPublic = m.IsPublic,
                IsStatic = m.IsStatic,
                IsVirtual = m.IsVirtual && !m.IsFinal,
                IsOverride = IsOverride(m),
                Parameters = m.GetParameters().Select(p => new ParamDecl
                {
                    Name = p.Name ?? "",
                    Type = FormatTypeRef(p.ParameterType)
                }).ToList(),
                ReturnType = FormatTypeRef(m.ReturnType),
                Attributes = ExtractAttributes(m.GetCustomAttributesData())
            })
            .ToList();
    }

    static List<PropertyDecl> ExtractProperties(Type type)
    {
        var flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly;

        return type.GetProperties(flags)
            .Where(p => !IsCompilerGenerated(p))
            .Select(p => new PropertyDecl
            {
                Name = p.Name,
                Type = FormatTypeRef(p.PropertyType),
                IsPublic = (p.GetMethod?.IsPublic ?? false) || (p.SetMethod?.IsPublic ?? false),
                HasGetter = p.GetMethod != null,
                HasSetter = p.SetMethod != null
            })
            .ToList();
    }

    static List<FieldDecl> ExtractFields(Type type)
    {
        if (type.IsEnum) return [];

        var flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly;

        return type.GetFields(flags)
            .Where(f => !IsCompilerGenerated(f))
            .Select(f => new FieldDecl
            {
                Name = f.Name,
                Type = FormatTypeRef(f.FieldType),
                IsPublic = f.IsPublic,
                IsStatic = f.IsStatic,
                IsReadonly = f.IsInitOnly || f.IsLiteral
            })
            .ToList();
    }

    static List<string> ExtractAttributes(IList<CustomAttributeData> attrs)
    {
        return attrs
            .Where(a => !IsInfrastructureAttribute(a))
            .Select(FormatAttribute)
            .ToList();
    }

    static List<string> ExtractTags(IList<CustomAttributeData> attrs)
    {
        return attrs
            .Where(a => a.AttributeType.Name == "CodeStructureTagAttribute")
            .SelectMany(a => a.ConstructorArguments)
            .Where(a => a.Value is string)
            .Select(a => (string)a.Value!)
            .ToList();
    }

    static string FormatAttribute(CustomAttributeData attr)
    {
        var name = attr.AttributeType.Name;
        if (name.EndsWith("Attribute"))
            name = name[..^"Attribute".Length];

        if (attr.ConstructorArguments.Count == 0) return name;

        var args = string.Join(", ", attr.ConstructorArguments.Select(a => a.Value?.ToString() ?? "null"));
        return $"{name}:{args}";
    }

    static bool IsInfrastructureAttribute(CustomAttributeData attr)
    {
        var ns = attr.AttributeType.Namespace ?? "";
        if (ns == "System.Runtime.CompilerServices") return true;
        if (ns == "System.Diagnostics.CodeAnalysis") return true;

        var name = attr.AttributeType.Name;
        return name is "CompilerGeneratedAttribute"
            or "NullableAttribute"
            or "NullableContextAttribute"
            or "ExtensionAttribute";
    }

    static string FormatTypeName(Type type)
    {
        if (!type.IsGenericTypeDefinition) return type.Name;

        var backtick = type.Name.IndexOf('`');
        if (backtick < 0) return type.Name;

        var baseName = type.Name[..backtick];
        var args = string.Join(", ", type.GetGenericArguments().Select(a => a.Name));
        return $"{baseName}<{args}>";
    }

    static string FormatTypeRef(Type type)
    {
        if (type.IsByRef)
            return FormatTypeRef(type.GetElementType()!);

        if (type.IsArray)
            return FormatTypeRef(type.GetElementType()!) + "[]";

        if (type.IsGenericParameter)
            return type.Name;

        if (type.IsGenericType)
        {
            var def = type.GetGenericTypeDefinition();
            if (def.FullName == "System.Nullable`1")
                return FormatTypeRef(type.GetGenericArguments()[0]) + "?";

            var backtick = type.Name.IndexOf('`');
            var baseName = backtick > 0 ? type.Name[..backtick] : type.Name;
            var args = string.Join(", ", type.GetGenericArguments().Select(FormatTypeRef));
            return $"{baseName}<{args}>";
        }

        return type.FullName switch
        {
            "System.Void" => "void",
            "System.Boolean" => "bool",
            "System.Byte" => "byte",
            "System.SByte" => "sbyte",
            "System.Char" => "char",
            "System.Int16" => "short",
            "System.UInt16" => "ushort",
            "System.Int32" => "int",
            "System.UInt32" => "uint",
            "System.Int64" => "long",
            "System.UInt64" => "ulong",
            "System.Single" => "float",
            "System.Double" => "double",
            "System.Decimal" => "decimal",
            "System.String" => "string",
            "System.Object" => "object",
            _ => type.Name
        };
    }

    static bool IsOverride(MethodInfo method)
    {
        return method.IsVirtual
            && (method.Attributes & MethodAttributes.NewSlot) == 0;
    }

    static bool IsCompilerGenerated(MemberInfo member)
    {
        return member.GetCustomAttributesData()
            .Any(a => a.AttributeType.FullName == "System.Runtime.CompilerServices.CompilerGeneratedAttribute");
    }

    static Type[] LoadTypes(Assembly assembly)
    {
        try
        {
            return assembly.GetTypes();
        }
        catch (ReflectionTypeLoadException ex)
        {
            foreach (var le in ex.LoaderExceptions.Where(e => e != null).DistinctBy(e => e!.Message))
                Console.Error.WriteLine($"warning: {le!.Message}");

            return ex.Types.Where(t => t != null).ToArray()!;
        }
    }

    static MetadataAssemblyResolver BuildResolver(string assemblyPath)
    {
        var paths = new HashSet<string>();

        var assemblyDir = Path.GetDirectoryName(assemblyPath);
        if (assemblyDir != null)
        {
            foreach (var dll in Directory.GetFiles(assemblyDir, "*.dll"))
                paths.Add(dll);
        }

        var runtimeDir = RuntimeEnvironment.GetRuntimeDirectory();
        foreach (var dll in Directory.GetFiles(runtimeDir, "*.dll"))
            paths.Add(dll);

        return new PathAssemblyResolver(paths);
    }
}
