package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

var (
	version   = "dev"     // set via -ldflags
	commitSHA = "unknown" // set via -ldflags
	buildDate = "unknown" // set via -ldflags
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{
			"ok":        "true",
			"version":   version,
			"commit":    commitSHA,
			"buildDate": buildDate,
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("listening on %s (commit %s)", port, commitSHA)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
