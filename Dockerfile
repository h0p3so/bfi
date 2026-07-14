FROM alpine:latest

WORKDIR /bfi

RUN apk add --no-cache curl make gcc musl-dev cowsay --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN curl -LO "https://raw.githubusercontent.com/h0p3so/xvargs/refs/heads/main/xvargs.S"
RUN curl -LO "https://raw.githubusercontent.com/h0p3so/tiny-pf/refs/heads/main/tiny-pf.S"

COPY . .

CMD ["cowsay", "run the image as an interactive one, then make and execute the interpreter"]
