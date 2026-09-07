<script>
	import { isLoggedIn } from '@/utils/token.js'

	export default {
		onLaunch: function() {
			// 启动强制登录（决策：App 启动即要求登录态）
			// 无 token 则跳转登录页，reLaunch 清空页面栈避免返回键回到需登录的页面
			if (!isLoggedIn()) {
				uni.reLaunch({ url: '/pages/login/login' })
			}
		},
		onShow: function() {
			console.log('App Show')
		},
		onHide: function() {
			console.log('App Hide')
		}
	}
</script>

<style>
	/*每个页面公共css */
	/* 禁用页面根容器自身滚动，避免与内部 scroll-view 出现双滚动条 */
	page {
		height: 100%;
		overflow: hidden;
	}
	html,
	body {
		height: 100%;
		overflow: hidden;
	}

	/* 隐藏 scroll-view 在 H5 下的默认滚动条，保持移动端观感 */
	.uni-scroll-view::-webkit-scrollbar {
		display: none;
		width: 0;
		height: 0;
	}
	.uni-scroll-view {
		scrollbar-width: none; /* Firefox */
		-ms-overflow-style: none; /* 旧 Edge / IE */
	}
</style>
