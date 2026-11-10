# Etapa 1: Compilación
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY . .

RUN dotnet restore ./src/Web.ControlAccesos/Web.ControlAccesos.csproj

RUN dotnet publish ./src/Web.ControlAccesos/Web.ControlAccesos.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# Etapa 2: Ejecución
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:8080

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "dotnet Web.ControlAccesos.dll --urls http://0.0.0.0:${PORT:-8080}"]
