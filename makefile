TOOLS := make git flex bison autoconf gcc g++ zip unzip apt-transport-https curl gnupg bazel help2man perl python3 ccache cmake gettext gperf check libslang2-dev

SYS_UPDATE  := apt-get update
SYS_INSTALL := apt-get install -y
SYS_UPGRADE := apt-get upgrade -y
SYS_CHECK   := apt list

# Git URL's
verible:     GIT := chipsalliance/verible
verilator:   GIT := verilator/verilator
iverilog:    GIT := steveicarus/iverilog
neovim:      GIT := neovim/neovim
svlint:      GIT := dalance/svlint
bat:         GIT := sharkdp/bat
ripgrep:     GIT := BurntSushi/ripgrep
lsd:         GIT := lsd-rs/lsd
du-dust:     GIT := bootandy/dust
fd-find:     GIT := sharkdp/fd
hyperfine:   GIT := sharkdp/hyperfine
fzf:         GIT := junegunn/fzf
bender:      GIT := pulp-platform/bender
ctags:       GIT := universal-ctags/ctags
mc:          GIT := MidnightCommander/mc
svls:        GIT := dalance/svls
veridian:    GIT := vivekmalneedi/veridian

# Make specific args
neovim: MAKE_ARGS := CMAKE_BUILD_TYPE=Release

MAKE_TARGETS := verilator iverilog neovim ctags mc
CARGO_TARGETS := bat ripgrep lsd du-dust fd-find hyperfine bender veridian

.PHONY: check_dep svlint verible $(MAKE_TARGETS) $(CARGO_TARGETS) fzf
default all: verible svlint $(CARGO_TARGETS) $(MAKE_TARGETS) fzf 

check_dep:
	@$(foreach _,$(TOOLS),$(if $(shell apt list $(_) 2>/dev/null|grep installed),,$(eval INSTALL_LIST += $(_)))) \
	$(if $(INSTALL_LIST),\
		$(info List to install: $(INSTALL_LIST)) \
		if ! [ `which bazel` ]; then \
			curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >/tmp/bazel.gpg && \
			sudo mv /tmp/bazel.gpg /usr/share/keyrings/bazel.gpg && \
			echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/bazel.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8' | sudo tee /etc/apt/sources.list.d/bazel.list; \
		fi; \
		sudo $(SYS_UPDATE) && \
		sudo $(SYS_INSTALL) $(INSTALL_LIST);, \
		$(info No packages to install) \
		sudo $(SYS_UPDATE) && \
		sudo $(SYS_UPGRADE); \
	) \
	if ! [ `which cargo` ]; then \
		curl https://sh.rustup.rs -sSf | sh; \
	else \
		rustup update; \
	fi;

verible:
	@if ! [ -d ./$@ ]; then \
		git clone https://github.com/$(GIT).git; \
		cd ./$@; git reset --hard HEAD~; cd ..;\
	fi; \
	git -C ./$@ fetch origin -q > /dev/null; \
	echo "=== Update $@ ==="; \
	echo "Installed version: `git -C ./$@ rev-parse --short HEAD`"; \
	echo "Latest version: `git -C ./$@ rev-parse --short origin/master`"; \
	if [ `git -C ./$@ rev-parse HEAD` != `git -C ./$@ rev-parse origin/master` ]; then \
		echo "====================" && \
		cd ./$@ && \
		git switch master && \
		git pull && \
		bazel build -c opt //... && \
		bazel test -c opt //... && \
		bazel run -c opt :install -- -s /usr/local/bin; \
	fi;

fzf:
	@if ! [ -d ./$@ ]; then \
		git clone https://github.com/$(GIT).git $@; \
		cd ./$@; git reset --hard HEAD~; cd ..;\
	fi; \
	git -C ./$@ fetch origin -q > /dev/null; \
	echo "=== Update $@ ==="; \
	echo "Installed version: `git -C ./$@ rev-parse --short HEAD`"; \
	echo "Latest version: `git -C ./$@ rev-parse --short origin/master`"; \
	if [ `git -C ./$@ rev-parse HEAD` != `git -C ./$@ rev-parse origin/master` ]; then \
		echo "====================" && \
		cd ./$@ && \
		git switch master && \
		git pull && \
		./install --all --no-fish; \
	fi;


$(CARGO_TARGETS):
	@if ! [ -d ./$@ ]; then \
		git clone https://github.com/$(GIT).git $@; \
		cd ./$@; git reset --hard HEAD~; cd ..;\
	fi; \
	git -C ./$@ fetch origin -q > /dev/null; \
	echo "=== Update $@ ==="; \
	echo "Installed version: `git -C ./$@ rev-parse --short HEAD`"; \
	echo "Latest version: `git -C ./$@ rev-parse --short origin/master`"; \
	if [ `git -C ./$@ rev-parse HEAD` != `git -C ./$@ rev-parse origin/master` ]; then \
		echo "====================" && \
		cd ./$@ && \
		git switch master && \
		git pull && \
		cargo build --release && \
		cp `find target/release/ -maxdepth 1 -type f -executable` ~/.cargo/bin/ ; \
#		cargo install --force $@;\
	fi;

$(MAKE_TARGETS):
	@if ! [ -d ./$@ ]; then \
		git clone https://github.com/$(GIT).git $@; \
		cd ./$@; git reset --hard HEAD~; cd ..;\
	fi; \
	git -C ./$@ fetch origin -q > /dev/null; \
	echo "=== Update $@ ==="; \
	echo "Installed version: `git -C ./$@ rev-parse --short HEAD`"; \
	echo "Latest version: `git -C ./$@ rev-parse --short origin/master`"; \
	if [ `git -C ./$@ rev-parse HEAD` != `git -C ./$@ rev-parse origin/master` ]; then \
		echo "====================" && \
		cd ./$@ && \
		git switch master && \
		git pull && \
		if [ -f ./autogen.sh ]; then \
			./autogen.sh ;\
		fi; \
		if [ -f ./configure.ac ]; then \
			autoconf && \
			./configure; \
		fi; \
		make $(MAKE_ARGS) -j`nproc` && \
		sudo make install && \
		sudo make distclean; \
	fi;

