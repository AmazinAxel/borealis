{
  services.printing = {
    enable = true;
    browsed.enable = false; # CUPS uses ipp
  };
  environment.persistence."/persist".directories = [ "/var/lib/cups" ]; # printer config
}
