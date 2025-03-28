package com.cicdpipeline.service;

import com.cicdpipeline.model.BuildInfo;
import org.springframework.stereotype.Service;

@Service
public class BuildService {

    public BuildInfo getCurrentBuildInfo() {
        BuildInfo buildInfo = new BuildInfo();
        buildInfo.setId("BUILD-" + System.currentTimeMillis());
        buildInfo.setStatus("Operational");
        buildInfo.setStartTime(System.currentTimeMillis());
        return buildInfo;
    }

    public String getBuildStatus() {
        // In a real-world scenario, this would interact with your CI/CD system
        return "Running";
    }
}