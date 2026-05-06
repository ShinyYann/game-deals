addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)

  // Health check
  if (url.pathname === '/') {
    return new Response('Steam Proxy OK', {
      headers: { 'Content-Type': 'text/plain' },
    })
  }

  // Get target URL from query
  const targetUrl = url.searchParams.get('url')
  if (!targetUrl) {
    return new Response('Missing ?url= parameter', { status: 400 })
  }

  // Security: only allow Steam domains
  const decoded = decodeURIComponent(targetUrl)
  const allowedDomains = [
    'steamcommunity.com',
    'store.steampowered.com',
    'media.steampowered.com',
    'cdn.cloudflare.steamstatic.com',
    'cdn.akamai.steamstatic.com',
  ]
  let allowed = false
  for (const domain of allowedDomains) {
    if (decoded.includes(domain)) {
      allowed = true
      break
    }
  }
  if (!allowed) {
    return new Response('Only Steam URLs are allowed', { status: 403 })
  }

  try {
    const response = await fetch(decoded, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      },
      redirect: 'follow',
    })

    const contentType = response.headers.get('Content-Type') || ''

    if (contentType.includes('text/html')) {
      let html = await response.text()

      // Inject <base> tag so relative URLs resolve correctly
      const baseUrl = decoded.substring(0, decoded.lastIndexOf('/') + 1)
      if (html.includes('<head>')) {
        html = html.replace('<head>', '<head><base href="' + baseUrl + '">')
      } else if (html.includes('<html>')) {
        html = html.replace('<html>', '<html><head><base href="' + baseUrl + '"></head>')
      } else {
        html = '<base href="' + baseUrl + '">' + html
      }

      return new Response(html, {
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
          'Access-Control-Allow-Origin': '*',
        },
      })
    }

    // Pass through non-HTML content (images, CSS, JS)
    return new Response(response.body, {
      status: response.status,
      headers: {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=3600',
      },
    })

  } catch (e) {
    return new Response('Proxy error: ' + e.message, { status: 502 })
  }
}
