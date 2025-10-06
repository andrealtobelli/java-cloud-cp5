package com.dimdim.controller;

import com.dimdim.model.Empresa;
import com.dimdim.model.Funcionario;
import com.dimdim.repository.EmpresaRepository;
import com.dimdim.repository.FuncionarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@Controller
@RequestMapping("/funcionarios")
public class FuncionarioController {
    @Autowired
    private FuncionarioRepository funcionarioRepository;
    @Autowired
    private EmpresaRepository empresaRepository;

    @GetMapping("/novo/{empresaId}")
    public String novoFuncionarioForm(@PathVariable Long empresaId, Model model) {
        Funcionario funcionario = new Funcionario();
        Optional<Empresa> empresa = empresaRepository.findById(empresaId);
        empresa.ifPresent(funcionario::setEmpresa);
        model.addAttribute("funcionario", funcionario);
        model.addAttribute("empresaId", empresaId);
        return "funcionario-form";
    }

    @PostMapping("/novo/{empresaId}")
    public String salvarFuncionario(@PathVariable Long empresaId, @ModelAttribute Funcionario funcionario) {
        Optional<Empresa> empresa = empresaRepository.findById(empresaId);
        empresa.ifPresent(funcionario::setEmpresa);
        funcionarioRepository.save(funcionario);
        return "redirect:/empresas/" + empresaId + "/funcionarios";
    }

    @GetMapping("/editar/{id}")
    public String editarFuncionarioForm(@PathVariable Long id, Model model) {
        Optional<Funcionario> funcionario = funcionarioRepository.findById(id);
        if (funcionario.isPresent()) {
            model.addAttribute("funcionario", funcionario.get());
            model.addAttribute("empresaId", funcionario.get().getEmpresa().getId());
            return "funcionario-form";
        }
        return "redirect:/empresas";
    }

    @PostMapping("/editar/{id}")
    public String atualizarFuncionario(@PathVariable Long id, @ModelAttribute Funcionario funcionario) {
        funcionario.setId(id);
        funcionarioRepository.save(funcionario);
        return "redirect:/empresas/" + funcionario.getEmpresa().getId() + "/funcionarios";
    }

    @GetMapping("/excluir/{id}")
    public String excluirFuncionario(@PathVariable Long id) {
        Optional<Funcionario> funcionario = funcionarioRepository.findById(id);
        if (funcionario.isPresent()) {
            Long empresaId = funcionario.get().getEmpresa().getId();
            funcionarioRepository.deleteById(id);
            return "redirect:/empresas/" + empresaId + "/funcionarios";
        }
        return "redirect:/empresas";
    }
}
