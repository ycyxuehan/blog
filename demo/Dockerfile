FROM golang:1.15 as builder
WORKDIR /workspace
ENV GOPROXY=https://goproxy.cn,direct GO111MODULE=on
COPY main.go main.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o main main.go && mkdir /data

FROM scratch
COPY --from=builder /workspace/main /
COPY --from=builder /data /
VOLUME ["/data"]
EXPOSE 8080
ENTRYPOINT ["/main"]
