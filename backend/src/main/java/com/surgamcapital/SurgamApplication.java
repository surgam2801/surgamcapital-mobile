package com.surgamcapital;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SurgamApplication {
    public static void main(String[] args) {
        SpringApplication.run(SurgamApplication.class, args);
    }
}
