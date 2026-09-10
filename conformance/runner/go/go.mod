module github.com/basecamp/fizzy-sdk/conformance/runner/go

go 1.26.6

require github.com/basecamp/fizzy-sdk/go v0.0.0

require (
	github.com/danieljoos/wincred v1.2.3 // indirect
	github.com/godbus/dbus/v5 v5.2.2 // indirect
	github.com/zalando/go-keyring v0.2.8 // indirect
	golang.org/x/sys v0.47.0 // indirect
)

replace github.com/basecamp/fizzy-sdk/go => ../../../go
