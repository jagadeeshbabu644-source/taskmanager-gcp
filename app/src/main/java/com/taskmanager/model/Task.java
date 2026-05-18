package com.taskmanager.model;
public class Task {
    private int id;
    private String title;
    private String description;
    private String status;
    private String priority;
    private long createdAt;
    public Task() {}
    public Task(int id, String title, String description, String priority) {
        this.id = id; this.title = title;
        this.description = description; this.priority = priority;
        this.status = "pending"; this.createdAt = System.currentTimeMillis();
    }
    public int    getId()                  { return id; }
    public void   setId(int id)            { this.id = id; }
    public String getTitle()               { return title; }
    public void   setTitle(String t)       { this.title = t; }
    public String getDescription()         { return description; }
    public void   setDescription(String d) { this.description = d; }
    public String getStatus()              { return status; }
    public void   setStatus(String s)      { this.status = s; }
    public String getPriority()            { return priority; }
    public void   setPriority(String p)    { this.priority = p; }
    public long   getCreatedAt()           { return createdAt; }
    public void   setCreatedAt(long t)     { this.createdAt = t; }
}
