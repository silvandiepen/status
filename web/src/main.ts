import '@sil/ui/styles'
import './styles/app.scss'

import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'

import App from './App.vue'
import ChangelogView from './views/ChangelogView.vue'
import DevelopersView from './views/DevelopersView.vue'
import DocsView from './views/DocsView.vue'
import DownloadView from './views/DownloadView.vue'
import HomeView from './views/HomeView.vue'
import PluginDetailView from './views/PluginDetailView.vue'
import PluginsView from './views/PluginsView.vue'
import PrivacyView from './views/PrivacyView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/download/', component: DownloadView },
    { path: '/plugins/', component: PluginsView },
    { path: '/plugins/:pluginId/', component: PluginDetailView },
    { path: '/developers/', component: DevelopersView },
    { path: '/docs/', component: DocsView },
    { path: '/privacy/', component: PrivacyView },
    { path: '/changelog/', component: ChangelogView },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

createApp(App).use(router).mount('#app')
