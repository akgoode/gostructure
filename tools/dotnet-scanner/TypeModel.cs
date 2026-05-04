using System.Text.Json.Serialization;

namespace DotnetScanner;

public sealed class AssemblyInventory
{
    [JsonPropertyName("assembly")]
    public string Assembly { get; set; } = "";

    [JsonPropertyName("path")]
    public string Path { get; set; } = "";

    [JsonPropertyName("namespaces")]
    public List<NamespaceInventory> Namespaces { get; set; } = [];
}

public sealed class NamespaceInventory
{
    [JsonPropertyName("namespace")]
    public string Namespace { get; set; } = "";

    [JsonPropertyName("types")]
    public List<TypeInventory> Types { get; set; } = [];
}

public sealed class TypeInventory
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("kind")]
    public string Kind { get; set; } = "";

    [JsonPropertyName("is_public")]
    public bool IsPublic { get; set; }

    [JsonPropertyName("is_abstract")]
    public bool IsAbstract { get; set; }

    [JsonPropertyName("is_sealed")]
    public bool IsSealed { get; set; }

    [JsonPropertyName("is_static")]
    public bool IsStatic { get; set; }

    [JsonPropertyName("base_type")]
    public string? BaseType { get; set; }

    [JsonPropertyName("interfaces")]
    public List<string> Interfaces { get; set; } = [];

    [JsonPropertyName("attributes")]
    public List<string> Attributes { get; set; } = [];

    [JsonPropertyName("generic_parameters")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<string>? GenericParameters { get; set; }

    [JsonPropertyName("constructors")]
    public List<ConstructorDecl> Constructors { get; set; } = [];

    [JsonPropertyName("methods")]
    public List<MethodDecl> Methods { get; set; } = [];

    [JsonPropertyName("properties")]
    public List<PropertyDecl> Properties { get; set; } = [];

    [JsonPropertyName("fields")]
    public List<FieldDecl> Fields { get; set; } = [];

    [JsonPropertyName("nested_types")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<string>? NestedTypes { get; set; }

    [JsonPropertyName("tags")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<string>? Tags { get; set; }
}

public sealed class ConstructorDecl
{
    [JsonPropertyName("is_public")]
    public bool IsPublic { get; set; }

    [JsonPropertyName("parameters")]
    public List<ParamDecl> Parameters { get; set; } = [];
}

public sealed class MethodDecl
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("is_public")]
    public bool IsPublic { get; set; }

    [JsonPropertyName("is_static")]
    public bool IsStatic { get; set; }

    [JsonPropertyName("is_virtual")]
    public bool IsVirtual { get; set; }

    [JsonPropertyName("is_override")]
    public bool IsOverride { get; set; }

    [JsonPropertyName("parameters")]
    public List<ParamDecl> Parameters { get; set; } = [];

    [JsonPropertyName("return_type")]
    public string ReturnType { get; set; } = "";

    [JsonPropertyName("attributes")]
    public List<string> Attributes { get; set; } = [];
}

public sealed class ParamDecl
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("type")]
    public string Type { get; set; } = "";
}

public sealed class PropertyDecl
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("is_public")]
    public bool IsPublic { get; set; }

    [JsonPropertyName("has_getter")]
    public bool HasGetter { get; set; }

    [JsonPropertyName("has_setter")]
    public bool HasSetter { get; set; }
}

public sealed class FieldDecl
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("type")]
    public string Type { get; set; } = "";

    [JsonPropertyName("is_public")]
    public bool IsPublic { get; set; }

    [JsonPropertyName("is_static")]
    public bool IsStatic { get; set; }

    [JsonPropertyName("is_readonly")]
    public bool IsReadonly { get; set; }
}
