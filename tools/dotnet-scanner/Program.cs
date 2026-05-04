using System.Text.Json;
using DotnetScanner;

if (args.Length != 1)
{
    Console.Error.WriteLine("Usage: dotnet-scanner <assembly.dll>");
    return 1;
}

var assemblyPath = args[0];
if (!File.Exists(assemblyPath))
{
    Console.Error.WriteLine($"Assembly not found: {assemblyPath}");
    return 1;
}

try
{
    var inventory = AssemblyScanner.Scan(assemblyPath);
    var options = new JsonSerializerOptions
    {
        WriteIndented = true,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.Never
    };
    Console.WriteLine(JsonSerializer.Serialize(inventory, options));
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Error scanning assembly: {ex.Message}");
    return 1;
}
