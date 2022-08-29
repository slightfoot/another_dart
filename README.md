## Another World in Dart/Flutter

### Building

You should be able to run as normal:
`flutter run`

It'll run fine on MacOS but complain it cannot locate the
SDL library files (used only for audio). You'll need to
copy the `.dylib` files from the project directory into
the output project directory.

Example. `cp *.dylib build/macos/Build/Products/Debug/another_dart.app/` 
