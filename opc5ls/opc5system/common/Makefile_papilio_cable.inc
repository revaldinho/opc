deploy: $(TARGET).bit
	papilio-prog -v -f $(TARGET).bit

program: $(TARGET).bit
	papilio-prog -v -b $(BSCAN) -f $(TARGET).bit -sa -r
	papilio-prog -c
