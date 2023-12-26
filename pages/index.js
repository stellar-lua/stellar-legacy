import Link from "@docusaurus/Link"
import useDocusaurusContext from "@docusaurus/useDocusaurusContext"
import Layout from "@theme/Layout"
import clsx from "clsx"
import React from "react"
import styles from "./index.module.css"

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext()

  const titleClassName = clsx("hero__title", {
    [styles.titleOnBannerImage]: false
  })
  const taglineClassName = clsx("hero__subtitle", {
    [styles.taglineOnBannerImage]: false
  })

  return (
    <header className={clsx("hero", styles.heroBanner)}>
      <div className="container">
        <h1 className={titleClassName}>{siteConfig.title}</h1>
        <p className={taglineClassName}>{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro"
          >
            Get Started →
          </Link>
        </div>
      </div>
    </header>
  )
}

export default function Home() {
  const { siteConfig, tagline } = useDocusaurusContext()
  return (
    <Layout title={siteConfig.title} description={tagline}>
      <HomepageHeader />
      <main>
        <div className="container">
          <h1>Hello, World</h1>
        </div>
      </main>
    </Layout>
  )
}