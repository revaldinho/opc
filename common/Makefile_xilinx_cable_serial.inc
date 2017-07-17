deploy: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g" <$(COMMON)/deploy.batch >deploy.batch
	impact -batch deploy.batch
	rm -f deploy.batch

program: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g;s@#PROM#@$(PROM)@g" <$(COMMON)/program_serial.batch >program_serial.batch
	impact -batch program_serial.batch
	rm -f program_serial.batch
