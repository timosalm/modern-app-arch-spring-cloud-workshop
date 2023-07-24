package com.example.productservice.product;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping(ProductResource.BASE_URI)
public class ProductResource {
  
  static final String BASE_URI = "/api/v1/products";

  @GetMapping
  public ResponseEntity<String> fetchProducts() {
      return ResponseEntity.ok("Hello World");
  }
}
