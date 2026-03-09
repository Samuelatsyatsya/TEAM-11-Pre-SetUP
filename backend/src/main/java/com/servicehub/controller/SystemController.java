package com.servicehub.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;

@RestController
@RequestMapping("${app.api.base-path}")
public class SystemController {

    @Value("${spring.application.name}")
    private String applicationName;

    @Value("${app.version}")
    private String applicationVersion;

    @Value("${app.environment}")
    private String environment;

    @GetMapping
    public Map<String, String> root() {
        return Map.of(
                "name", applicationName,
                "version", applicationVersion,
                "environment", environment,
                "status", "ok"
        );
    }

    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of(
                "status", "ok",
                "timestamp", OffsetDateTime.now(ZoneOffset.UTC).toString()
        );
    }
}
