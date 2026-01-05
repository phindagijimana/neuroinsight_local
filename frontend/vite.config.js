import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8006',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      },
      '/jobs': 'http://localhost:8006',
      '/upload': 'http://localhost:8006',
      '/health': 'http://localhost:8006',
      '/docs': 'http://localhost:8006'
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: true
  }
})
