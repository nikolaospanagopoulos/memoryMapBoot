./bin/os.bin: ./bin/boot.bin ./bin/second_stage.bin 
	rm -f ./bin/os.bin
	cat ./bin/boot.bin ./bin/second_stage.bin > ./bin/os.bin
	dd if=/dev/zero bs=512 count=100 >> ./bin/os.bin
./bin/boot.bin: ./boot.asm
	fasm ./boot.asm ./bin/boot.bin
./bin/second_stage.bin: ./second_stage.asm
	fasm ./second_stage.asm ./bin/second_stage.bin
clean:
	rm ./bin/*.bin
