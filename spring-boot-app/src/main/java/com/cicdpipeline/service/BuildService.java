package com.cicdpipeline.service;

import com.cicdpipeline.model.BuildInfo;
import org.springframework.stereotype.Service;

@Service
public class BuildService {

    public BuildInfo getCurrentBuildInfo() {
        BuildInfo buildInfo = new BuildInfo();
        buildInfo.setId("BUILD-" + System.currentTimeMillis());  // Generating a unique build ID
        buildInfo.setStatus("Operational");  // You can dynamically update this based on real data
        buildInfo.setStartTime(System.currentTimeMillis());  // This can be the time the build started
        return buildInfo;
    }

    public String getBuildStatus() {
        // This method can be enhanced to interact with a CI/CD system (e.g., Jenkins)
        // For now, it's returning a placeholder value
        return "Running";  // You can modify this to be dynamic as per your CI/CD pipeline
    }
}
