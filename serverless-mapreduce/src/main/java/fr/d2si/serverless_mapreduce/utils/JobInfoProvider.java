package fr.d2si.serverless_mapreduce.utils;

import com.google.gson.Gson;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

public class JobInfoProvider {
    private static class JobInfoHolder {
        static Gson gson = new Gson();
        static InputStream driverInfoStream = JobInfoProvider.class.getClassLoader().getResourceAsStream("jobInfo.json");
        static BufferedReader driverInfoReader = new BufferedReader(new InputStreamReader(driverInfoStream));
        private static final JobInfo JOB_INFO = gson.fromJson(driverInfoReader, JobInfo.class);
    }

    public static JobInfo getJobInfo() {
        return JobInfoHolder.JOB_INFO;
    }

    private JobInfoProvider() {
    }
}
