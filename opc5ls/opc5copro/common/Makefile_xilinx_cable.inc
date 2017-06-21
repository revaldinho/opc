deploy: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g" <$(COMMON)/deploy.batch >deploy.batch
	impact -batch deploy.batch
	rm -f deploy.batch

program: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g;s@#PROM#@$(PROM)@g" <$(COMMON)/program.batch >program.batch
	impact -batch program.batch
	rm -f program.batch
