# PTY::Recorder

Run a fully interactive command in a PTY.

With this library you can run any unix command, hook the input and output of the command to $stdin and $stdout, and also record the input and output as it happens.

## Usage

Basic command running:

    inlog = ""
    PTYRecorder.spawn('irb --simple-prompt', inlog: inlog) # blocks until user exits irb
    puts "You typed:"
    puts inlog.inspect

