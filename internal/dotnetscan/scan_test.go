package dotnetscan

import (
	"encoding/json"
	"testing"
)

func TestDeserializeAssemblyInventory(t *testing.T) {
	input := `{
		"assembly": "SampleLib",
		"path": "SampleLib.dll",
		"namespaces": [
			{
				"namespace": "SampleLib.Orders",
				"types": [
					{
						"name": "OrderService",
						"kind": "class",
						"is_public": true,
						"is_abstract": false,
						"is_sealed": true,
						"is_static": false,
						"base_type": null,
						"interfaces": ["IOrderService"],
						"attributes": [],
						"constructors": [
							{
								"is_public": true,
								"parameters": [
									{"name": "repository", "type": "IOrderRepository"},
									{"name": "options", "type": "OrderServiceOptions"}
								]
							}
						],
						"methods": [
							{
								"name": "CreateOrder",
								"is_public": true,
								"is_static": false,
								"is_virtual": false,
								"is_override": false,
								"parameters": [
									{"name": "request", "type": "CreateOrderRequest"}
								],
								"return_type": "Task<OrderResult>",
								"attributes": []
							}
						],
						"properties": [],
						"fields": [
							{
								"name": "_repository",
								"type": "IOrderRepository",
								"is_public": false,
								"is_static": false,
								"is_readonly": true
							}
						]
					}
				]
			}
		]
	}`

	var inv AssemblyInventory
	if err := json.Unmarshal([]byte(input), &inv); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	if inv.Assembly != "SampleLib" {
		t.Errorf("assembly = %q, want SampleLib", inv.Assembly)
	}
	if len(inv.Namespaces) != 1 {
		t.Fatalf("namespaces = %d, want 1", len(inv.Namespaces))
	}

	ns := inv.Namespaces[0]
	if ns.Namespace != "SampleLib.Orders" {
		t.Errorf("namespace = %q, want SampleLib.Orders", ns.Namespace)
	}
	if len(ns.Types) != 1 {
		t.Fatalf("types = %d, want 1", len(ns.Types))
	}

	typ := ns.Types[0]
	if typ.Name != "OrderService" {
		t.Errorf("type name = %q, want OrderService", typ.Name)
	}
	if typ.Kind != "class" {
		t.Errorf("kind = %q, want class", typ.Kind)
	}
	if !typ.IsPublic {
		t.Error("is_public = false, want true")
	}
	if !typ.IsSealed {
		t.Error("is_sealed = false, want true")
	}
	if typ.IsStatic {
		t.Error("is_static = true, want false")
	}
	if len(typ.Interfaces) != 1 || typ.Interfaces[0] != "IOrderService" {
		t.Errorf("interfaces = %v, want [IOrderService]", typ.Interfaces)
	}

	if len(typ.Constructors) != 1 {
		t.Fatalf("constructors = %d, want 1", len(typ.Constructors))
	}
	ctor := typ.Constructors[0]
	if !ctor.IsPublic {
		t.Error("constructor is_public = false, want true")
	}
	if len(ctor.Parameters) != 2 {
		t.Fatalf("constructor params = %d, want 2", len(ctor.Parameters))
	}
	if ctor.Parameters[0].Type != "IOrderRepository" {
		t.Errorf("param[0].type = %q, want IOrderRepository", ctor.Parameters[0].Type)
	}

	if len(typ.Methods) != 1 {
		t.Fatalf("methods = %d, want 1", len(typ.Methods))
	}
	method := typ.Methods[0]
	if method.Name != "CreateOrder" {
		t.Errorf("method name = %q, want CreateOrder", method.Name)
	}
	if method.ReturnType != "Task<OrderResult>" {
		t.Errorf("return type = %q, want Task<OrderResult>", method.ReturnType)
	}

	if len(typ.Fields) != 1 {
		t.Fatalf("fields = %d, want 1", len(typ.Fields))
	}
	field := typ.Fields[0]
	if field.Name != "_repository" {
		t.Errorf("field name = %q, want _repository", field.Name)
	}
	if field.IsPublic {
		t.Error("field is_public = true, want false")
	}
	if !field.IsReadonly {
		t.Error("field is_readonly = false, want true")
	}
}

func TestDeserializeInterface(t *testing.T) {
	input := `{
		"assembly": "TestLib",
		"path": "TestLib.dll",
		"namespaces": [{
			"namespace": "TestLib",
			"types": [{
				"name": "IOrderService",
				"kind": "interface",
				"is_public": true,
				"is_abstract": false,
				"is_sealed": false,
				"is_static": false,
				"base_type": null,
				"interfaces": [],
				"attributes": [],
				"constructors": [],
				"methods": [
					{
						"name": "GetOrder",
						"is_public": true,
						"is_static": false,
						"is_virtual": true,
						"is_override": false,
						"parameters": [{"name": "id", "type": "Guid"}],
						"return_type": "Task<Order>",
						"attributes": []
					}
				],
				"properties": [],
				"fields": []
			}]
		}]
	}`

	var inv AssemblyInventory
	if err := json.Unmarshal([]byte(input), &inv); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	typ := inv.Namespaces[0].Types[0]
	if typ.Kind != "interface" {
		t.Errorf("kind = %q, want interface", typ.Kind)
	}
	if !typ.Methods[0].IsVirtual {
		t.Error("interface method is_virtual = false, want true")
	}
}

func TestDeserializeNullBaseType(t *testing.T) {
	input := `{
		"assembly": "TestLib",
		"path": "TestLib.dll",
		"namespaces": [{
			"namespace": "TestLib",
			"types": [{
				"name": "MyClass",
				"kind": "class",
				"is_public": true,
				"is_abstract": false,
				"is_sealed": false,
				"is_static": false,
				"base_type": null,
				"interfaces": [],
				"attributes": [],
				"constructors": [],
				"methods": [],
				"properties": [],
				"fields": []
			}]
		}]
	}`

	var inv AssemblyInventory
	if err := json.Unmarshal([]byte(input), &inv); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	if inv.Namespaces[0].Types[0].BaseType != nil {
		t.Error("base_type should be nil for object-derived class")
	}
}

func TestDeserializeWithBaseType(t *testing.T) {
	input := `{
		"assembly": "TestLib",
		"path": "TestLib.dll",
		"namespaces": [{
			"namespace": "TestLib",
			"types": [{
				"name": "OrderNotFoundException",
				"kind": "class",
				"is_public": true,
				"is_abstract": false,
				"is_sealed": false,
				"is_static": false,
				"base_type": "Exception",
				"interfaces": [],
				"attributes": [],
				"constructors": [],
				"methods": [],
				"properties": [],
				"fields": []
			}]
		}]
	}`

	var inv AssemblyInventory
	if err := json.Unmarshal([]byte(input), &inv); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	bt := inv.Namespaces[0].Types[0].BaseType
	if bt == nil || *bt != "Exception" {
		t.Errorf("base_type = %v, want Exception", bt)
	}
}

func TestScanValidation(t *testing.T) {
	_, err := Scan("not-a-dll.txt")
	if err == nil {
		t.Fatal("expected error for non-dll path")
	}

	_, err = Scan("nonexistent.dll")
	if err == nil {
		t.Fatal("expected error for nonexistent file")
	}
}
