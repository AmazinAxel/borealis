# Add a printer (no mDNS discovery, so use its IP from the router or printer menu):
#   sudo lpadmin -p <name> -E -v ipp://<printer-ip>/ipp/print -m everywhere
#   lpoptions -d <name>  # make default
# Test: lp -d <name> <file>; list: lpstat -v; remove: sudo lpadmin -x <name>
# Or use the web UI at http://localhost:631
{
  services.printing = {
    enable = true;
    browsed.enable = false; # CUPS uses ipp
  };
  environment.persistence."/persist".directories = [ "/var/lib/cups" ]; # printer config
}
