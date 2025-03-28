package com.cicdpipeline;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@SpringBootApplication
@Controller
public class StartApplication {

    @GetMapping("/")
    public String index(final Model model) {
        // Generic, descriptive title and message
        model.addAttribute("title", "DevOps CI/CD Pipeline Dashboard");
        model.addAttribute("msg", "Continuous Integration and Deployment Platform");
        
        // Optional: Add build status
        model.addAttribute("buildStatus", "Operational");
        
        // Optional: Add timestamp for cache busting
        model.addAttribute("timestamp", System.currentTimeMillis());
        
        return "index";
    }

    public static void main(String[] args) {
        SpringApplication.run(StartApplication.class, args);
    }
}