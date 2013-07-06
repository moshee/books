package main

import (
	"./books"
	"github.com/moshee/gas"
)

func main() {
	gas.New().
		Get("/", books.Index)

	err := gas.Ignition()
	if err != nil {
		gas.Log(gas.Fatal, err)
	}
}
