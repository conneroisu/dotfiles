package main

import (
	_ "embed"
	"log"
	"net/http"

	inertia "github.com/romsar/gonertia/v2"
)

//go:embed resources/views/root.html
var rootTemplate string

func main() {
	// Initialize Inertia
	i, err := inertia.New(rootTemplate,
		inertia.WithVersion("1.0.0"),
		// inertia.WithSSR("http://127.0.0.1:13714"), // Enable SSR if needed
	)
	if err != nil {
		log.Fatal(err)
	}

	// Create router
	mux := http.NewServeMux()

	// Serve static files
	mux.Handle("/build/", http.StripPrefix("/build/", http.FileServer(http.Dir("./public/build"))))

	// Routes
	mux.Handle("/", i.Middleware(homeHandler(i)))
	mux.Handle("/about", i.Middleware(aboutHandler(i)))
	mux.Handle("/contact", i.Middleware(contactHandler(i)))

	// Start server
	log.Println("Server started on http://localhost:3336")
	log.Fatal(http.ListenAndServe(":3336", mux))
}

func homeHandler(i *inertia.Inertia) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := i.Render(w, r, "Home", inertia.Props{
			"title": "Welcome to Inertia + Go + React",
			"message": "Build amazing single-page apps without building an API.",
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})
}

func aboutHandler(i *inertia.Inertia) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		err := i.Render(w, r, "About", inertia.Props{
			"title": "About Us",
			"content": "This is a demo of Inertia.js with Go and React.",
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})
}

func contactHandler(i *inertia.Inertia) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			// Handle form submission
			r.ParseForm()
			name := r.FormValue("name")
			email := r.FormValue("email")
			message := r.FormValue("message")

			// Process the form data here...
			log.Printf("Contact form submitted: %s <%s> - %s", name, email, message)

			// Redirect back with success message
			i.Location(w, r, "/contact")
			return
		}

		err := i.Render(w, r, "Contact", inertia.Props{
			"title": "Contact Us",
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})
}