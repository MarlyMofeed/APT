// package googledocsclone.configurations;

// import googledocsclone.example.googledocsclone.models.User;
// import googledocsclone.example.googledocsclone.repositories.UserRepository;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
// import org.springframework.security.core.context.SecurityContextHolder;
// import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
// import org.springframework.stereotype.Component;
// import org.springframework.util.StringUtils;
// import org.springframework.web.filter.OncePerRequestFilter;
// import services.JwtTokenProvider;


// import javax.servlet.FilterChain;
// import javax.servlet.ServletException;
// import javax.servlet.http.HttpServletRequest;
// import javax.servlet.http.HttpServletResponse;
// import java.io.IOException;

// @Component
// public class JwtAuthenticationFilter extends OncePerRequestFilter {

//     @Autowired
//     private UserRepository userRepository;

//     @Autowired
//     private JwtTokenProvider tokenProvider;

//     @Override
//     protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
//             throws ServletException, IOException {
//         try {
//             String jwt = getJwtFromRequest(request);

//             if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
//                 Long userId = tokenProvider.getUserIdFromJWT(jwt);

//                 User userDetails = userRepository.findById(userId).orElse(null);
//                 if (userDetails != null) {
//                     UsernamePasswordAuthenticationToken
//                             authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
//                     authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

//                     SecurityContextHolder.getContext().setAuthentication(authentication);
//                 }
//             }
//         } catch (Exception ex) {
//             logger.error("Could not set user authentication in security context", ex);
//         }

//         filterChain.doFilter(request, response);
//     }

//     private String getJwtFromRequest(HttpServletRequest request) {
//         String bearerToken = request.getHeader("Authorization");
//         if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
//             return bearerToken.substring(7, bearerToken.length());
//         }
//         return null;
//     }
// }
