// mw-tool: moewalls.com için liste çekme (fetch) ve video URL çözme (resolve).
// Python + venv yerine geçer — tek statik binary, harici bağımlılık yok.
//
// Kullanım:
//   mw-tool fetch   "https://moewalls.com/page/1/"
//   mw-tool resolve "https://moewalls.com/anime/.../"
//
// fetch  çıktısı (stdout): JSON liste -> [{"url":...,"thumb":...,"title":...}]
// resolve çıktısı (stdout): tek satır video URL'si (bulunamazsa boş satır)
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

const ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
	"(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

func fetchHTML(url string) (string, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", ua)
	req.Header.Set("Referer", "https://moewalls.com/")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("http %d", resp.StatusCode)
	}

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

type result struct {
	URL   string `json:"url"`
	Thumb string `json:"thumb"`
	Title string `json:"title"`
}

var (
	articleRE   = regexp.MustCompile(`(?s)<article.*?>(.*?)</article>`)
	mediaLinkRE = regexp.MustCompile(`entry-featured-media[^>]*>\s*<a[^>]+href="([^"]+)"`)
	imgRE       = regexp.MustCompile(`<img[^>]+(?:data-src|src)="([^"]+)"`)
	titleRE     = regexp.MustCompile(`entry-title[^>]*>\s*(?:<a[^>]*>)?\s*([^<]+)`)
)

func doFetch(url string) int {
	html, err := fetchHTML(url)
	if err != nil {
		fmt.Println("[]")
		fmt.Fprintln(os.Stderr, "HATA:", err)
		return 1
	}

	var results []result
	for _, a := range articleRE.FindAllStringSubmatch(html, -1) {
		if len(results) >= 9 {
			break
		}
		block := a[1]
		m := mediaLinkRE.FindStringSubmatch(block)
		i := imgRE.FindStringSubmatch(block)
		t := titleRE.FindStringSubmatch(block)
		if m == nil || i == nil {
			continue
		}
		title := ""
		if t != nil {
			title = strings.TrimSpace(t[1])
		}
		results = append(results, result{URL: m[1], Thumb: i[1], Title: title})
	}
	if results == nil {
		results = []result{}
	}
	out, _ := json.Marshal(results)
	fmt.Println(string(out))
	return 0
}

var videoRE = regexp.MustCompile(`(/wp-content/uploads/preview/[^\s"'<>]+?\.(?:webm|mp4))`)

func doResolve(url string) int {
	html, err := fetchHTML(url)
	if err != nil {
		fmt.Println()
		fmt.Fprintln(os.Stderr, "HATA:", err)
		return 1
	}
	m := videoRE.FindStringSubmatch(html)
	if m == nil {
		fmt.Println()
		return 0
	}
	path := m[1]
	if strings.HasPrefix(path, "http") {
		fmt.Println(path)
	} else {
		fmt.Println("https://moewalls.com" + path)
	}
	return 0
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "kullanım: mw-tool fetch|resolve <url>")
		os.Exit(1)
	}
	switch os.Args[1] {
	case "fetch":
		os.Exit(doFetch(os.Args[2]))
	case "resolve":
		os.Exit(doResolve(os.Args[2]))
	default:
		fmt.Fprintln(os.Stderr, "bilinmeyen komut:", os.Args[1])
		os.Exit(1)
	}
}
