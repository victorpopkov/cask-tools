package general

// Stolen from:
//   https://github.com/VonC/godbg/blob/master/exit/exit.go

import "os"

// ExitFunc takes a code as exit status.
type ExitFunc func(int)

// Exit has an exit func, and will memorize the exit status code.
type Exit struct {
	exit   ExitFunc
	status int
}

// New returns an exiter with a custom function
func NewExit(exit ExitFunc) *Exit {
	return &Exit{exit: exit}
}

// Exit calls the exiter, and then returns code as status.
func (e *Exit) Exit(code int) {
	e.status = code
	e.exit(code)
}

// Status get the exit status code as memorized after the call to the exit func.
func (e *Exit) Status() int {
	return e.status
}

// Default returns an Exit with default os.Exit() call. That means the status
// will never be visible, since os.Exit() stops everything.
func DefaultExit() *Exit {
	return &Exit{exit: os.Exit}
}
