package main

// SystemCmd is the command for managing system configurations.
type SystemCmd struct {
	Create SystemCreate `cmd:"" help:"create a system configuration"`
}

// SystemCreate is the command for creating a system image.
type SystemCreate struct {
	Image string `arg:"" help:"image to create"`
}

// Run runs the command.
func (c *SystemCreate) Run() error {
	println("creating system image", c.Image)
	return nil
}
