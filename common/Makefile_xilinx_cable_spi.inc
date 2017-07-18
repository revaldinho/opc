deploy: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g" <$(COMMON)/deploy.batch >deploy.batch
	impact -batch deploy.batch
	rm -f deploy.batch

program: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g;s@#PROM#@$(PROM)@g" <$(COMMON)/program_spi.batch >program_spi.batch
	impact -batch program_spi.batch
	rm -f program_spi.batch
