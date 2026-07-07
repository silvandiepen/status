import '@sil/ui/styles'
import './styles/app.scss'

import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'

import App from './App.vue'
import DevelopersView from './views/DevelopersView.vue'
import HomeView from './views/HomeView.vue'
import PluginsView from './views/PluginsView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/plugins/', component: PluginsView },
    { path: '/developers/', component: DevelopersView },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})

createApp(App).use(router).mount('#app')
