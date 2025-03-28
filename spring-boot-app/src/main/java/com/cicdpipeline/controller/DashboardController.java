package com.cicdpipeline.controller;

import com.cicdpipeline.service.BuildService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class DashboardController {

    private final BuildService buildService;

    @Autowired
    public DashboardController(BuildService buildService) {
        this.buildService = buildService;
    }

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("title", "DevOps CI/CD Pipeline Dashboard");
        model.addAttribute("msg", "Continuous Integration and Deployment Platform");
        
        // Add build information
        model.addAttribute("buildInfo", buildService.getCurrentBuildInfo());
        model.addAttribute("buildStatus", buildService.getBuildStatus());
        model.addAttribute("timestamp", System.currentTimeMillis());
        
        return "index";
    }
}