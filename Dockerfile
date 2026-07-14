FROM alpine:latest

WORKDIR /bfi

RUN apk add --no-cache curl make gcc musl-dev cowsay --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN curl -LO "https://raw.githubusercontent.com/h0p3so/xvargs/refs/heads/main/xvargs.S"
RUN curl -LO "https://raw.githubusercontent.com/h0p3so/tiny-pf/refs/heads/main/tiny-pf.S"
RUN mkdir programs

RUN curl -LO https://brainfuck.org/e.b
RUN curl -LO https://brainfuck.org/sierpinski.b
RUN curl -LO https://brainfuck.org/squares.b
RUN curl -LO https://raw.githubusercontent.com/skeeto/bf-x86/refs/heads/master/samples/mandelbrot.bf
RUN curl -LO https://raw.githubusercontent.com/skeeto/bf-x86/refs/heads/master/samples/hanoi.bf
RUN curl -LO https://brainfuck.org/life.b
RUN mv *b programs
RUN mv *bf programs

COPY . .

CMD ["cowsay", "run the image as an interactive one, then make and execute the interpreter"]
