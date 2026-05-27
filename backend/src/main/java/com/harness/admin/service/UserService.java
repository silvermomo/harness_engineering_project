package com.harness.admin.service;

import com.harness.admin.dto.LoginRequest;
import com.harness.admin.dto.LoginResponse;
import com.harness.admin.dto.UserCreateRequest;
import com.harness.admin.entity.User;
import com.harness.admin.repository.UserRepository;
import com.harness.admin.security.JwtTokenUtil;
import com.harness.admin.util.RsaKeyUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenUtil jwtTokenUtil;
    private final RsaKeyUtil rsaKeyUtil;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        try {
            String decryptedPassword = rsaKeyUtil.decryptByPrivateKey(request.getEncryptedPassword());
            log.info("User login attempt: {}", request.getUsername());
            log.info("Decrypted password length: {}", decryptedPassword.length());

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getUsername(),
                            decryptedPassword
                    )
            );

            User user = userRepository.findByUsername(request.getUsername())
                    .orElseThrow(() -> new RuntimeException("用户不存在"));

            user.setLastLoginIp("127.0.0.1");
            user.setLastLoginTime(LocalDateTime.now());
            userRepository.save(user);

            String token = jwtTokenUtil.generateToken(authentication.getPrincipal().toString());

            log.info("User logged in successfully: {}", request.getUsername());

            return new LoginResponse(
                    token,
                    "Bearer",
                    jwtTokenUtil.getExpiration(),
                    new LoginResponse.UserInfo(
                            user.getId(),
                            user.getUsername(),
                            user.getRealName(),
                            user.getRole(),
                            user.getSuperAdmin()
                    )
            );
        } catch (Exception e) {
            log.error("Login failed for user: {}, error: {}", request.getUsername(), e.getMessage(), e);
            throw new RuntimeException("登录失败: " + e.getMessage());
        }
    }

    @Transactional
    public User createUser(UserCreateRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }

        if (request.getEmail() != null && userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("邮箱已被使用");
        }

        if (request.getPhone() != null && userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("手机号已被使用");
        }

        User user = User.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .realName(request.getRealName())
                .phone(request.getPhone())
                .email(request.getEmail())
                .role(request.getRole())
                .enabled(request.getEnabled())
                .accountNonLocked(true)
                .accountNonExpired(true)
                .credentialsNonExpired(true)
                .superAdmin(false)
                .build();

        return userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public User findByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("用户不存在: " + username));
    }

    public String getPublicKey() {
        return rsaKeyUtil.getPublicKey();
    }
}
