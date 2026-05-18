package com.taskmanager.controller;
import com.taskmanager.model.Task;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
@RestController
@CrossOrigin(origins = "*")
public class TaskController {
    private final Map<Integer, Task> tasks   = new ConcurrentHashMap<>();
    private final AtomicInteger      counter = new AtomicInteger(0);
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("status", "healthy"); r.put("version", "1.0.0");
        r.put("timestamp", System.currentTimeMillis());
        return r;
    }
    @GetMapping("/api/tasks")
    public Map<String, Object> getTasks(@RequestParam(required=false) String status) {
        List<Task> result = new ArrayList<>(tasks.values());
        if (status != null && !status.isEmpty())
            result = result.stream()
                .filter(t -> t.getStatus().equals(status))
                .collect(Collectors.toList());
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("tasks", result); resp.put("count", result.size());
        return resp;
    }
    @PostMapping("/api/tasks")
    public ResponseEntity<Task> createTask(@RequestBody Map<String, String> body) {
        if (!body.containsKey("title") || body.get("title").isBlank())
            return ResponseEntity.badRequest().build();
        int id = counter.incrementAndGet();
        Task task = new Task(id, body.get("title"),
            body.getOrDefault("description", ""),
            body.getOrDefault("priority", "medium"));
        tasks.put(id, task);
        return ResponseEntity.status(201).body(task);
    }
    @PutMapping("/api/tasks/{id}")
    public ResponseEntity<Task> updateTask(@PathVariable int id,
            @RequestBody Map<String, String> body) {
        Task task = tasks.get(id);
        if (task == null) return ResponseEntity.notFound().build();
        if (body.containsKey("status"))      task.setStatus(body.get("status"));
        if (body.containsKey("title"))       task.setTitle(body.get("title"));
        if (body.containsKey("description")) task.setDescription(body.get("description"));
        return ResponseEntity.ok(task);
    }
    @DeleteMapping("/api/tasks/{id}")
    public ResponseEntity<Map<String, Object>> deleteTask(@PathVariable int id) {
        Task removed = tasks.remove(id);
        if (removed == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(Map.of("deleted", removed));
    }
    @GetMapping("/api/stats")
    public Map<String, Long> stats() {
        Collection<Task> all = tasks.values();
        Map<String, Long> r = new LinkedHashMap<>();
        r.put("total",       (long) all.size());
        r.put("pending",     all.stream().filter(t->"pending".equals(t.getStatus())).count());
        r.put("in_progress", all.stream().filter(t->"in_progress".equals(t.getStatus())).count());
        r.put("completed",   all.stream().filter(t->"completed".equals(t.getStatus())).count());
        return r;
    }
}
