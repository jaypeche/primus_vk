# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils multilib-build

DESCRIPTION="Vulkan GPU-offloading layer"
HOMEPAGE="https://github.com/felixdoerre/primus_vk"

case ${PV} in
9999)
	SRC_URI=""
	EGIT_REPO_URI="https://github.com/felixdoerre/primus_vk.git"
	VK_VERSION="9999"
	inherit git-r3
	;;
*)
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/felixdoerre/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	RESTRICT="mirror"
	S="${WORKDIR}/${PN}-${PV}"
	VK_VERSION="1.3.204"
	;;
esac

LICENSE="BSD-2"
SLOT="0"
IUSE="debug multilib"

RDEPEND=">=dev-util/vulkan-headers-${VK_VERSION}
	multilib? ( >=media-libs/vulkan-layers-${VK_VERSION}[${MULTILIB_USEDEP}]
		>=media-libs/vulkan-loader-${VK_VERSION}[${MULTILIB_USEDEP}]
		>=x11-drivers/nvidia-drivers-460.91.03[${MULTILIB_USEDEP}]
		>=x11-misc/primus-0.2-r3[${MULTILIB_USEDEP}] )
	!multilib? ( >=media-libs/vulkan-layers-${VK_VERSION}
		>=media-libs/vulkan-loader-${VK_VERSION}
		x86? ( >=x11-drivers/nvidia-drivers-390.144 )
		>=x11-misc/primus-0.2-r3 )
	>=x11-misc/bumblebee-3.2.1_p20210112-r4"

DEPEND="virtual/opengl"

src_prepare() {
	default
	eapply "${FILESDIR}/primus_vk_gentoo_header_fix.diff" || die "epatch failed !"
	eapply "${FILESDIR}/primus_vk_gentoo_prefix.diff" || die "epatch failed !"
	eapply "${FILESDIR}/primus_vk_gentoo_primus_segfault_workaround_issue86.diff" || die "epatch failed !"
	eapply "${FILESDIR}/primus_vk_gentoo_readme.md_update.diff" || die "epatch failed !"

	if use debug; then
		eapply "${FILESDIR}/primus_vk_gentoo_dialog_shell_default_path_fix.diff" || die "epatch failed !"
		eapply "${FILESDIR}/primus_vk_gentoo_debug_tool.diff" || die "epatch failed !"
	fi
	if use multilib; then
		multilib_copy_sources
		cd "${WORKDIR}/${P}-abi_x86_64.amd64"
		eapply "${FILESDIR}/primus_vk_gentoo_nv_driver_path_amd64.diff" || die "epatch failed !"

		cd "${WORKDIR}/${P}-abi_x86_32.x86"
		eapply "${FILESDIR}/primus_vk_gentoo_nv_driver_path_x86.diff" || die "epatch failed !"
	else
		if use x86; then
			eapply "${FILESDIR}/primus_vk_gentoo_nv_driver_path_x86.diff" || die "epatch failed !"
		fi
		if use amd64; then
			eapply "${FILESDIR}/primus_vk_gentoo_nv_driver_path_amd64.diff" || die "epatch failed !"
		fi
	fi
}

src_compile() {
	if use multilib; then
	mymake() {
		emake LIBDIR=$(get_libdir) all || die
	}
	multilib_parallel_foreach_abi mymake
	else
		emake LIBDIR=$(get_libdir) all || die
	fi
}

src_install() {
	if use multilib; then
	myinst() {
		if multilib_is_native_abi; then
			cd "${WORKDIR}/${P}-abi_x86_64.amd64"
			emake DESTDIR="${D}" LIBDIR=lib64 install || die
		else
			cd "${WORKDIR}/${P}-abi_x86_32.x86"
			emake DESTDIR="${D}" LIBDIR=lib install || die
		fi
	}
	multilib_foreach_abi myinst
	else
		emake DESTDIR="${D}" LIBDIR=$(get_libdir) install || die
	fi
	dodoc {README.md,LICENSE} || die "dodoc failed !"
	docinto html
	dodoc "${FILESDIR}/README.html" || die "dohtml failed !"
}
