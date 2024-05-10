import { IBM_Plex_Sans_Condensed, Sora } from 'next/font/google'
import { headers } from 'next/headers'

import { CSSProperties } from 'react'

import { cookieToInitialState } from 'wagmi'

import Navigation from '@/src/components/Navigation'
import Web3ModalProvider from '@/src/components/Web3ModalProvider'
import { config } from '@/src/config/wagmi'
import '@/src/scss/index.scss'

import styles from './layout.module.scss'

const fontSora = Sora({
  weight: ['400', '500'],
  subsets: ['latin-ext'],
  variable: '--font-sora',
})
const fontIbm = IBM_Plex_Sans_Condensed({
  weight: ['400', '500'],
  subsets: ['latin-ext'],
  variable: '--font-ibm',
})

export const metadata = {
  title: 'Create Next App',
  description: 'Generated by create next app',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const initialState = cookieToInitialState(config, headers().get('cookie'))

  return (
    <html lang="en">
      <body
        style={
          {
            '--font-sora': fontSora.style.fontFamily,
            '--font-ibm': fontIbm.style.fontFamily,
          } as CSSProperties
        }>
        <Web3ModalProvider initialState={initialState}>
          <div className={styles.container}>
            <div className={styles.panel}>
              <Navigation />
            </div>
            <div className={styles.content}>{children}</div>
          </div>
        </Web3ModalProvider>
      </body>
    </html>
  )
}
