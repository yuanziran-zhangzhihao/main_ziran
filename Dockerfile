FROM scratch

WORKDIR /app
COPY routerd /app/routerd

EXPOSE 8080
CMD ["/app/routerd"]
