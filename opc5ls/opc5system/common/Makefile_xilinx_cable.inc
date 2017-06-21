deploy: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g" <../common/deploy.batch >deploy.batch
	impact -batch deploy.batch

program: $(TARGET).bit
	sed "s@#TARGET#@$(TARGET)@g;s@#PROM#@$(PROM)@g" <../common/program.batch >program.batch
	impact -batch program.batch
