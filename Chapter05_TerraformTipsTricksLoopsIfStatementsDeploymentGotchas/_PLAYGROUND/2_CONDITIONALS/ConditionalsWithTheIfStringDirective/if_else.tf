variable "name" {
  description = "A name to render"
  type        = string
}

output "if_else_directive" {
  value = "Hello, %{if var.name != ""}${var.name}%{else}(unnamed)%{endif}"
}

# terraform apply -var name="World"
# terraform apply -var name="" 
