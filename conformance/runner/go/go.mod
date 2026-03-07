module github.com/basecamp/fizzy-sdk/conformance/runner/go

go 1.26

require github.com/basecamp/fizzy-sdk/go v0.0.0

require (
	al.essio.dev/pkg/shellescape v1.5.1 // indirect
	github.com/danieljoos/wincred v1.2.2 // indirect
	github.com/godbus/dbus/v5 v5.1.0 // indirect
	github.com/zalando/go-keyring v0.2.6 // indirect
	golang.org/x/sys v0.30.0 // indirect
)

replace github.com/basecamp/fizzy-sdk/go => ../../../go
