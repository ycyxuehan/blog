package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/gomarkdown/markdown"
	"github.com/gomarkdown/markdown/html"
	"github.com/gomarkdown/markdown/parser"
)

func main(){
	file, err := os.Open("test.md")
	if err != nil {
		panic(err)
	}
	defer file.Close()
	data, err := ioutil.ReadAll(file)
	if err != nil {
		panic(err)
	}
	htmlFlags := html.CommonFlags | html.HrefTargetBlank | html.CompletePage
	var extensions = parser.NoIntraEmphasis |
		parser.Tables |
		parser.FencedCode |
		parser.Autolink |
		parser.Strikethrough |
		parser.SpaceHeadings
	opts := html.RendererOptions{
		Flags: htmlFlags, 
		CSS: "http://www.bing89.com/css/markdown/fluent.css",
	}
	renderer := html.NewRenderer(opts)
	parser := parser.NewWithExtensions(extensions)
	html := markdown.ToHTML(data, parser, renderer)
	fmt.Println(string(html))
}