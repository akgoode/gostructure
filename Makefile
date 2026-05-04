.PHONY: build build-go build-dotnet test test-go test-policies clean

build: build-go build-dotnet

build-go:
	go build -o code-structure ./cmd/code-structure

build-dotnet:
	dotnet publish tools/dotnet-scanner -c Release -o ./bin/dotnet-scanner

test: test-go test-policies

test-go:
	go test ./...

test-policies:
	conftest verify -p policy/go
	conftest verify -p policy/dotnet

clean:
	rm -f code-structure
	rm -rf bin/dotnet-scanner
	rm -rf tools/dotnet-scanner/bin tools/dotnet-scanner/obj
	rm -rf tools/dotnet-scanner/testdata/*/bin tools/dotnet-scanner/testdata/*/obj
