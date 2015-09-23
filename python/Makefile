.PHONY: clean reinstall test all

all: reinstall test

clean:
	-pip uninstall scs
	$(RM) -rf scs.so *.egg-info *.pyc dist build scs.c

reinstall: clean
	pip install -e .

test:
	nosetests -vs
