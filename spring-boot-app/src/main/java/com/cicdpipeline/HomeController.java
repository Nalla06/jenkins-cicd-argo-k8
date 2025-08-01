package com.cicdpipeline;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/home")
    public String index(final Model model) {
        model.addAttribute("title", "DevOps CI/CD Pipeline Dashboard");
        model.addAttribute("msg", "Continuous Integration and Deployment Platform");
        model.addAttribute("timestamp", System.currentTimeMillis());
        return "index";
    }
}
