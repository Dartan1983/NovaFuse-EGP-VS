# NovaFuse-EGP-VS - Docker Runner
# For CI/CD environments and automated testing

FROM mcr.microsoft.com/powershell:7.2-nanoserver-1809
SHELL ["pwsh", "-Command"]

# Copy harness and run verification
COPY NovaFuse-EGP-VS/ /harness/
WORKDIR /harness

# Set execution policy for scripts
RUN Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Run verification (artifacts will be mounted as volume)
ENTRYPOINT ["pwsh", "-Command", "./verifier/verify.ps1"]

# Default to working directory
WORKDIR /harness/verifier

# Run the harness
CMD ["./verify.ps1"]
